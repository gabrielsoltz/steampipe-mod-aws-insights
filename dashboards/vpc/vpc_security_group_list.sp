dashboard "aws_vpc_security_group_list" {

  title = "AWS VPC Security Group List"
  documentation = file("./dashboards/vpc/docs/vpc_security_group_dashboard.md")

  tags = merge(local.vpc_common_tags, {
    type = "Dashboard"
  })

  container {

  input "filter_is_associated" {
    option "true" {}
    option "false" {}
  }

    card {
      sql = query.aws_vpc_security_group_count.sql
      width = 2
      href = "/aws_insights.dashboard.aws_vpc_security_group_list?input.filter_is_associated=true"
    }

    card {
      sql = query.aws_vpc_security_group_unassociated_count.sql
      width = 2
      href = "/aws_insights.dashboard.aws_vpc_security_group_list?input.filter_is_associated=false"
    }

    card {
      sql = query.aws_vpc_security_unrestricted_ingress_count.sql
      width = 2
    }

    card {
      sql = query.aws_vpc_security_unrestricted_egress_count.sql
      width = 2
    }

    table {
      query = query.aws_vpc_security_group_list_with_params
      args = {
        filter_isassociated = self.input.filter_is_associated.value
      }
    }
  }
}

query "aws_vpc_security_group_list_with_params" {
  sql = <<-EOQ
    with association as (
      with associated_sg as (
        select
          sg ->> 'GroupId' as sg_id,
          sg ->> 'GroupName' as sg_name
        from
          aws_ec2_network_interface,
          jsonb_array_elements(groups) as sg
      )
      select
      distinct group_name, group_id, description, region, account_id, tags, a.sg_id as association,
      case when a.sg_id is null then false else true end as is_associated
      from
        aws_vpc_security_group s
        left join associated_sg a on s.group_id = a.sg_id
    )
    select
      group_name, group_id, description, region, account_id, tags, association, is_associated
    from association
    where 
      CASE 
        WHEN false = $1 THEN is_associated = false
        ELSE true
      END
      ;
  EOQ

  param "filter_isassociated" {}

}



  